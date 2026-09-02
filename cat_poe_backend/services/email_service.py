"""
Email service for sending verification codes and notifications
"""

import asyncio
import logging
import smtplib
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from config import settings

logger = logging.getLogger(__name__)


def _smtp_timeout_seconds() -> int:
    """Works with older deployments where Settings lacks SMTP_TIMEOUT_SECONDS."""
    raw = getattr(settings, "SMTP_TIMEOUT_SECONDS", 25)
    return max(5, int(raw))


def _smtp_starttls() -> bool:
    """Works with older deployments where Settings lacks SMTP_STARTTLS."""
    return bool(getattr(settings, "SMTP_STARTTLS", True))


def _deliver_smtp_sync(sender_email: str, sender_password: str, to_email: str, message: MIMEMultipart) -> None:
    host = settings.SMTP_SERVER
    port = int(settings.SMTP_PORT)
    timeout = _smtp_timeout_seconds()
    recipients = [to_email]
    payload = message.as_string()

    use_ssl = port == 465
    starttls = _smtp_starttls()

    logger.info(
        "SMTP send via %s:%s (%s) from=%s to=%s",
        host,
        port,
        "SSL" if use_ssl else ("STARTTLS" if starttls else "plain"),
        sender_email,
        to_email,
    )

    if use_ssl:
        with smtplib.SMTP_SSL(host, port, timeout=timeout) as server:
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, recipients, payload)
        return

    with smtplib.SMTP(host, port, timeout=timeout) as server:
        server.ehlo()
        if starttls:
            server.starttls()
            server.ehlo()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, recipients, payload)


async def _deliver_smtp_async(sender_email: str, sender_password: str, to_email: str, message: MIMEMultipart) -> None:
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(
        None,
        lambda: _deliver_smtp_sync(sender_email, sender_password, to_email, message),
    )


class EmailService:
    """Handle email sending operations"""

    @staticmethod
    def get_verification_expiry() -> datetime:
        """Get expiry time for verification code (15 minutes from now)"""
        return datetime.utcnow() + timedelta(minutes=15)

    @staticmethod
    def _smtp_config_ok(sender_email: str, sender_password: str) -> bool:
        if not sender_password:
            logger.error(
                "SMTP_PASSWORD is not set; cannot send mail "
                "(set SMTP_* in `.env` or the process environment)."
            )
            return False
        if not sender_email or "@" not in sender_email:
            logger.error(
                "SMTP_EMAIL must be a valid sender address (with @); got %r",
                sender_email,
            )
            return False
        return True

    @staticmethod
    async def send_verification_email(email: str, code: str, username: str) -> bool:
        """
        Send verification code email

        Args:
            email: Recipient email address
            code: 6-digit verification code
            username: Generated username for the user

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            sender_email = settings.SMTP_EMAIL
            sender_password = (settings.SMTP_PASSWORD or "").strip()

            # Console-only path: local dev without SMTP credentials (never in production/staging).
            if settings.ENVIRONMENT == "development" and not sender_password:
                print(f"\n{'='*60}")
                print(f"📧 VERIFICATION EMAIL (Development Mode)")
                print(f"{'='*60}")
                print(f"To: {email}")
                print(f"Username: {username}")
                print(f"Verification Code: {code}")
                print(f"Expires in: 15 minutes")
                print(f"{'='*60}\n")
                return True

            if not EmailService._smtp_config_ok(sender_email, sender_password):
                return False

            message = MIMEMultipart("alternative")
            message["Subject"] = "Verify Your Catcoin Account"
            message["From"] = f"Catcoin PoE <{sender_email}>"
            message["To"] = email

            plain = (
                f"Welcome to Catcoin PoE.\n\n"
                f"Email: {email}\n"
                f"Username: {username}\n\n"
                f"Verification code (expires in 15 minutes): {code}\n\n"
                f"If you didn't sign up for Catcoin PoE, ignore this email.\n"
            )
            message.attach(MIMEText(plain, "plain", "utf-8"))

            html = f"""
            <html>
              <body style="font-family: Arial, sans-serif; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto;">
                  <h2>Welcome to Catcoin PoE! 🐱</h2>
                  <p>Your account has been created. Here are your details:</p>
                  <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <p><strong>Email:</strong> {email}</p>
                    <p><strong>Username:</strong> {username}</p>
                  </div>
                  <p>Please verify your email address by entering this code in the app:</p>
                  <div style="background-color: #ff6b35; color: white; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; border-radius: 5px; margin: 20px 0; letter-spacing: 5px;">
                    {code}
                  </div>
                  <p style="color: #666; font-size: 14px;">This code will expire in 15 minutes.</p>
                  <p>If you didn't sign up for Catcoin, please ignore this email.</p>
                  <hr style="margin-top: 30px;">
                  <p style="color: #999; font-size: 12px;">Catcoin PoE - Mine, Earn, Thrive</p>
                </div>
              </body>
            </html>
            """
            message.attach(MIMEText(html, "html", "utf-8"))

            await _deliver_smtp_async(sender_email, sender_password, email, message)

            logger.info("Verification email accepted by SMTP server for %s", email)
            return True

        except smtplib.SMTPAuthenticationError as e:
            logger.error(
                "SMTP authentication failed for user %s on %s:%s — check SMTP_EMAIL/SMTP_PASSWORD (e.g. Gmail App Password). %s",
                settings.SMTP_EMAIL,
                settings.SMTP_SERVER,
                settings.SMTP_PORT,
                e,
            )
            if settings.ENVIRONMENT == "development":
                return True
            return False
        except smtplib.SMTPRecipientsRefused as e:
            logger.error("SMTP refused recipient %s: %s", email, e)
            return False
        except Exception as e:
            logger.exception("Failed to send verification email to %s: %s", email, e)
            if settings.ENVIRONMENT == "development":
                return True
            return False

    @staticmethod
    async def send_password_reset_email(email: str, code: str, username: str) -> bool:
        """Send password reset code (separate template from signup verification)."""
        try:
            sender_email = settings.SMTP_EMAIL
            sender_password = (settings.SMTP_PASSWORD or "").strip()

            if settings.ENVIRONMENT == "development" and not sender_password:
                print(f"\n{'='*60}")
                print(f"📧 PASSWORD RESET EMAIL (Development Mode)")
                print(f"{'='*60}")
                print(f"To: {email}")
                print(f"Username: {username}")
                print(f"Reset Code: {code}")
                print(f"Expires in: 15 minutes")
                print(f"{'='*60}\n")
                return True

            if not EmailService._smtp_config_ok(sender_email, sender_password):
                return False

            message = MIMEMultipart("alternative")
            message["Subject"] = "Reset your Catcoin PoE password"
            message["From"] = f"Catcoin PoE <{sender_email}>"
            message["To"] = email

            plain = (
                f"Password reset for Catcoin PoE.\n\n"
                f"Hi {username}, use this code in the app (expires in 15 minutes): {code}\n\n"
                f"If you did not request a reset, ignore this email.\n"
            )
            message.attach(MIMEText(plain, "plain", "utf-8"))

            html = f"""
            <html>
              <body style="font-family: Arial, sans-serif; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto;">
                  <h2>Password reset</h2>
                  <p>Hi {username}, use this code in the app to set a new password:</p>
                  <div style="background-color: #ff6b35; color: white; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; border-radius: 5px; margin: 20px 0; letter-spacing: 5px;">
                    {code}
                  </div>
                  <p style="color: #666; font-size: 14px;">This code will expire in 15 minutes.</p>
                  <p>If you did not request a reset, you can ignore this email.</p>
                </div>
              </body>
            </html>
            """
            message.attach(MIMEText(html, "html", "utf-8"))

            await _deliver_smtp_async(sender_email, sender_password, email, message)
            logger.info("Password reset email accepted by SMTP server for %s", email)
            return True
        except smtplib.SMTPAuthenticationError as e:
            logger.error(
                "SMTP authentication failed for password reset (%s:%s): %s",
                settings.SMTP_SERVER,
                settings.SMTP_PORT,
                e,
            )
            if settings.ENVIRONMENT == "development":
                return True
            return False
        except smtplib.SMTPRecipientsRefused as e:
            logger.error("SMTP refused password-reset recipient %s: %s", email, e)
            return False
        except Exception as e:
            logger.exception("Failed to send password reset email to %s: %s", email, e)
            if settings.ENVIRONMENT == "development":
                return True
            return False
