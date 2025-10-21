import pytest
import os
import sys

# Add the parent directory to the path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app  # noqa: E402
from models import db, Student  # noqa: E402


@pytest.fixture
def app():
    """Create application for testing"""
    app = create_app("testing")

    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()


@pytest.fixture
def client(app):
    """Create test client"""
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create test runner"""
    return app.test_cli_runner()


@pytest.fixture
def sample_student_data():
    """Sample student data for testing"""
    return {
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@example.com",
        "age": 20,
        "grade": "A",
    }


@pytest.fixture
def create_sample_student(app, sample_student_data):
    """Create a sample student in the database"""
    with app.app_context():
        student = Student(
            first_name=sample_student_data["first_name"],
            last_name=sample_student_data["last_name"],
            email=sample_student_data["email"],
            age=sample_student_data["age"],
            grade=sample_student_data["grade"],
        )
        db.session.add(student)
        db.session.commit()

        # Refresh the instance to avoid detached instance issues
        db.session.refresh(student)
        student_id = student.id
        student_email = student.email

        # Return just the values we need instead of the object
        return type(
            "Student",
            (),
            {
                "id": student_id,
                "email": student_email,
                "first_name": sample_student_data["first_name"],
                "last_name": sample_student_data["last_name"],
                "age": sample_student_data["age"],
                "grade": sample_student_data["grade"],
            },
        )()
