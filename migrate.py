#!/usr/bin/env python3
"""
Database migration script for the Student CRUD API
"""

import os
import sys
import logging
from flask import Flask
from models import db, Student
from config import config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app():
    """Create Flask app for migration"""
    app = Flask(__name__)
    
    # Use environment variable for database URL if provided
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        app.config['SQLALCHEMY_DATABASE_URI'] = database_url
    else:
        # Fallback to config
        config_name = os.getenv('FLASK_ENV', 'production')
        app.config.from_object(config[config_name])
    
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Initialize database
    db.init_app(app)
    
    return app

def run_migrations():
    """Run database migrations"""
    app = create_app()
    
    with app.app_context():
        try:
            logger.info("Starting database migration...")
            
            # Create all tables
            db.create_all()
            logger.info("Database tables created successfully")
            
            # Check if we need to seed initial data
            if Student.query.count() == 0:
                logger.info("Seeding initial data...")
                
                # Create sample students
                sample_students = [
                    Student(
                        first_name="John",
                        last_name="Doe", 
                        email="john.doe@example.com",
                        age=20,
                        grade="A"
                    ),
                    Student(
                        first_name="Jane",
                        last_name="Smith",
                        email="jane.smith@example.com", 
                        age=22,
                        grade="B"
                    ),
                    Student(
                        first_name="Bob",
                        last_name="Johnson",
                        email="bob.johnson@example.com",
                        age=19,
                        grade="A-"
                    )
                ]
                
                for student in sample_students:
                    db.session.add(student)
                
                db.session.commit()
                logger.info(f"Created {len(sample_students)} sample students")
            else:
                logger.info("Database already contains data, skipping seed")
                
            logger.info("Migration completed successfully")
            
        except Exception as e:
            logger.error(f"Migration failed: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    run_migrations()