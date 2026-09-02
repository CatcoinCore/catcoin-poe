"""Stable client-facing auth strings (enumeration-resistant where noted)."""

SIGNUP_ACK = (
    "If you can register with this email, you will receive a verification message shortly."
)
SIGNUP_EXISTING_UNVERIFIED_ACK = (
    "A verification code was sent to this email. Your password has been updated. "
    "Enter the code in the app to complete signup."
)
RESEND_VERIFICATION_ACK = (
    "If an account exists and needs email verification, a message may have been sent."
)
FORGOT_PASSWORD_ACK = (
    "If an account exists for this email, password reset instructions may have been sent."
)
INVALID_VERIFICATION_CODE = "Invalid or expired verification code."
INVALID_RESET_CODE = "Invalid or expired reset code."
EMAIL_DELIVERY_UNAVAILABLE = (
    "We could not send email right now. Please try again in a few minutes."
)
INVALID_REFRESH_TOKEN = "Invalid or expired refresh token."
REFRESH_REUSE_DETECTED = "Invalid or expired refresh token."
