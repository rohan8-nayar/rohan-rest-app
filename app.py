import os
import logging
from flask import Flask, request, jsonify
from flask_migrate import Migrate
from flask_cors import CORS
from models import db, Student
from config import config

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def create_app(config_name=None):
    """Application factory pattern"""
    app = Flask(__name__)

    # Load configuration
    config_name = config_name or os.getenv("FLASK_ENV", "development")
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)
    migrate = Migrate(app, db)  # noqa: F841
    CORS(app)

    # Get API version from config
    api_version = app.config["API_VERSION"]

    @app.route("/healthcheck", methods=["GET"])
    def healthcheck():
        """Health check endpoint"""
        logger.info("Health check requested")
        return (
            jsonify(
                {
                    "status": "healthy",
                    "message": "Student API is running",
                    "version": api_version,
                }
            ),
            200,
        )

    @app.route(f"/api/{api_version}/students", methods=["POST"])
    def create_student():
        """Create a new student"""
        try:
            data = request.get_json()

            # Validate required fields
            required_fields = ["first_name", "last_name", "email", "age"]
            for field in required_fields:
                if field not in data:
                    logger.warning(f"Missing required field: {field}")
                    return jsonify({"error": f"Missing required field: {field}"}), 400

            # Check if email already exists
            existing_student = Student.query.filter_by(email=data["email"]).first()
            if existing_student:
                logger.warning(f"Student with email {data['email']} already exists")
                return jsonify({"error": "Student with this email already exists"}), 409

            # Create new student
            student = Student(
                first_name=data["first_name"],
                last_name=data["last_name"],
                email=data["email"],
                age=data["age"],
                grade=data.get("grade"),
            )

            db.session.add(student)
            db.session.commit()

            logger.info(f"Created student with ID: {student.id}")
            return (
                jsonify(
                    {
                        "message": "Student created successfully",
                        "student": student.to_dict(),
                    }
                ),
                201,
            )

        except Exception as e:
            logger.error(f"Error creating student: {str(e)}")
            db.session.rollback()
            return jsonify({"error": "Internal server error"}), 500

    @app.route(f"/api/{api_version}/students", methods=["GET"])
    def get_all_students():
        """Get all students"""
        try:
            page = request.args.get("page", 1, type=int)
            per_page = request.args.get("per_page", 10, type=int)

            students = Student.query.paginate(
                page=page, per_page=per_page, error_out=False
            )

            logger.info(f"Retrieved {len(students.items)} students (page {page})")

            return (
                jsonify(
                    {
                        "students": [student.to_dict() for student in students.items],
                        "pagination": {
                            "page": page,
                            "per_page": per_page,
                            "total": students.total,
                            "pages": students.pages,
                            "has_next": students.has_next,
                            "has_prev": students.has_prev,
                        },
                    }
                ),
                200,
            )

        except Exception as e:
            logger.error(f"Error retrieving students: {str(e)}")
            return jsonify({"error": "Internal server error"}), 500

    @app.route(f"/api/{api_version}/students/<int:student_id>", methods=["GET"])
    def get_student(student_id):
        """Get a student by ID"""
        try:
            student = Student.query.get(student_id)

            if not student:
                logger.warning(f"Student with ID {student_id} not found")
                return jsonify({"error": "Student not found"}), 404

            logger.info(f"Retrieved student with ID: {student_id}")
            return jsonify({"student": student.to_dict()}), 200

        except Exception as e:
            logger.error(f"Error retrieving student {student_id}: {str(e)}")
            return jsonify({"error": "Internal server error"}), 500

    @app.route(f"/api/{api_version}/students/<int:student_id>", methods=["PUT"])
    def update_student(student_id):
        """Update a student by ID"""
        try:
            student = Student.query.get(student_id)

            if not student:
                logger.warning(f"Student with ID {student_id} not found for update")
                return jsonify({"error": "Student not found"}), 404

            data = request.get_json()

            # Check if email is being updated and if it already exists
            if "email" in data and data["email"] != student.email:
                existing_student = Student.query.filter_by(email=data["email"]).first()
                if existing_student:
                    logger.warning(
                        f"Email {data['email']} already exists for another student"
                    )
                    return (
                        jsonify({"error": "Email already exists for another student"}),
                        409,
                    )

            # Update fields
            updateable_fields = ["first_name", "last_name", "email", "age", "grade"]
            for field in updateable_fields:
                if field in data:
                    setattr(student, field, data[field])

            db.session.commit()

            logger.info(f"Updated student with ID: {student_id}")
            return (
                jsonify(
                    {
                        "message": "Student updated successfully",
                        "student": student.to_dict(),
                    }
                ),
                200,
            )

        except Exception as e:
            logger.error(f"Error updating student {student_id}: {str(e)}")
            db.session.rollback()
            return jsonify({"error": "Internal server error"}), 500

    @app.route(f"/api/{api_version}/students/<int:student_id>", methods=["DELETE"])
    def delete_student(student_id):
        """Delete a student by ID"""
        try:
            student = Student.query.get(student_id)

            if not student:
                logger.warning(f"Student with ID {student_id} not found for deletion")
                return jsonify({"error": "Student not found"}), 404

            db.session.delete(student)
            db.session.commit()

            logger.info(f"Deleted student with ID: {student_id}")
            return jsonify({"message": "Student deleted successfully"}), 200

        except Exception as e:
            logger.error(f"Error deleting student {student_id}: {str(e)}")
            db.session.rollback()
            return jsonify({"error": "Internal server error"}), 500

    @app.errorhandler(404)
    def not_found(error):
        logger.warning(f"404 error: {request.url}")
        return jsonify({"error": "Endpoint not found"}), 404

    @app.errorhandler(500)
    def internal_error(error):
        logger.error(f"500 error: {str(error)}")
        return jsonify({"error": "Internal server error"}), 500

    return app


# Create the Flask application
app = create_app()

if __name__ == "__main__":
    # Note: Database tables are created via migrations (migrate.py)
    # No need to create tables here since we use PostgreSQL with proper migrations

    # Run the application
    host = app.config["HOST"]
    port = app.config["PORT"]
    debug = app.config["DEBUG"]

    logger.info(f"Starting Student API on {host}:{port}")
    logger.info("Database tables should be created via 'make run-migrations'")
    app.run(host=host, port=port, debug=debug)
