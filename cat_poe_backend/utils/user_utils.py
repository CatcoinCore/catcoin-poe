"""
Utility functions for user management
"""
import random
from sqlalchemy import select
from models import User

async def generate_unique_username(db) -> str:
    """
    Generate a unique 9-digit username starting with 9
    Format: 900000000 to 999999999
    """
    max_attempts = 100
    
    for _ in range(max_attempts):
        # Generate random 9-digit number starting with 9
        username = str(random.randint(900000000, 999999999))
        
        # Check if username exists
        result = await db.execute(
            select(User).where(User.username == username)
        )
        existing_user = result.scalar_one_or_none()
        
        if not existing_user:
            return username
    
    raise Exception("Failed to generate unique username after maximum attempts")

def generate_verification_code() -> str:
    """Generate a 6-digit verification code"""
    return ''.join([str(random.randint(0, 9)) for _ in range(6)])
