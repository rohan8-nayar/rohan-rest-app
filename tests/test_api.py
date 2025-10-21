import json
from models import Student, db


class TestStudentAPI:
    """Test suite for Student CRUD API endpoints"""

    def test_healthcheck(self, client):
        """Test health check endpoint"""
        response = client.get("/healthcheck")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "healthy"
        assert "version" in data

    def test_create_student_success(self, client, sample_student_data):
        """Test successful student creation"""
        response = client.post(
            "/api/v1/students",
            data=json.dumps(sample_student_data),
            content_type="application/json",
        )

        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["message"] == "Student created successfully"
        assert data["student"]["first_name"] == sample_student_data["first_name"]
        assert data["student"]["email"] == sample_student_data["email"]
        assert "id" in data["student"]

    def test_create_student_missing_fields(self, client):
        """Test student creation with missing required fields"""
        incomplete_data = {
            "first_name": "John",
            "email": "john@example.com"
            # Missing last_name and age
        }

        response = client.post(
            "/api/v1/students",
            data=json.dumps(incomplete_data),
            content_type="application/json",
        )

        assert response.status_code == 400
        data = json.loads(response.data)
        assert "error" in data
        assert "Missing required field" in data["error"]

    def test_create_student_duplicate_email(self, client, sample_student_data):
        """Test student creation with duplicate email"""
        # Create first student
        client.post(
            "/api/v1/students",
            data=json.dumps(sample_student_data),
            content_type="application/json",
        )

        # Try to create another student with same email
        duplicate_data = sample_student_data.copy()
        duplicate_data["first_name"] = "Jane"

        response = client.post(
            "/api/v1/students",
            data=json.dumps(duplicate_data),
            content_type="application/json",
        )

        assert response.status_code == 409
        data = json.loads(response.data)
        assert "already exists" in data["error"]

    def test_get_all_students_empty(self, client):
        """Test getting all students when database is empty"""
        response = client.get("/api/v1/students")

        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["students"] == []
        assert data["pagination"]["total"] == 0

    def test_get_all_students_with_data(self, client, create_sample_student):
        """Test getting all students with data"""
        response = client.get("/api/v1/students")

        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data["students"]) == 1
        assert data["pagination"]["total"] == 1
        assert data["students"][0]["email"] == create_sample_student.email

    def test_get_all_students_pagination(self, client, app):
        """Test pagination for get all students"""
        # Create multiple students
        with app.app_context():
            for i in range(15):
                student = Student(
                    first_name=f"Student{i}",
                    last_name="Test",
                    email=f"student{i}@example.com",
                    age=20 + i,
                )
                db.session.add(student)
            db.session.commit()

        # Test first page
        response = client.get("/api/v1/students?page=1&per_page=10")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data["students"]) == 10
        assert data["pagination"]["page"] == 1
        assert data["pagination"]["total"] == 15
        assert data["pagination"]["has_next"] is True

        # Test second page
        response = client.get("/api/v1/students?page=2&per_page=10")
        data = json.loads(response.data)
        assert len(data["students"]) == 5
        assert data["pagination"]["has_next"] is False

    def test_get_student_by_id_success(self, client, create_sample_student):
        """Test getting student by valid ID"""
        student_id = create_sample_student.id
        response = client.get(f"/api/v1/students/{student_id}")

        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["student"]["id"] == student_id
        assert data["student"]["email"] == create_sample_student.email

    def test_get_student_by_id_not_found(self, client):
        """Test getting student by non-existent ID"""
        response = client.get("/api/v1/students/999")

        assert response.status_code == 404
        data = json.loads(response.data)
        assert data["error"] == "Student not found"

    def test_update_student_success(self, client, create_sample_student):
        """Test successful student update"""
        student_id = create_sample_student.id
        update_data = {"first_name": "Jane", "age": 25}

        response = client.put(
            f"/api/v1/students/{student_id}",
            data=json.dumps(update_data),
            content_type="application/json",
        )

        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["message"] == "Student updated successfully"
        assert data["student"]["first_name"] == "Jane"
        assert data["student"]["age"] == 25
        # Email should remain unchanged
        assert data["student"]["email"] == create_sample_student.email

    def test_update_student_not_found(self, client):
        """Test updating non-existent student"""
        update_data = {"first_name": "Jane"}

        response = client.put(
            "/api/v1/students/999",
            data=json.dumps(update_data),
            content_type="application/json",
        )

        assert response.status_code == 404
        data = json.loads(response.data)
        assert data["error"] == "Student not found"

    def test_update_student_duplicate_email(self, client, app, sample_student_data):
        """Test updating student with duplicate email"""
        with app.app_context():
            # Create two students
            student1 = Student(
                first_name="John", last_name="Doe", email="john@example.com", age=20
            )
            student2 = Student(
                first_name="Jane", last_name="Smith", email="jane@example.com", age=21
            )
            db.session.add(student1)
            db.session.add(student2)
            db.session.commit()

            # Try to update student2's email to student1's email
            response = client.put(
                f"/api/v1/students/{student2.id}",
                data=json.dumps({"email": "john@example.com"}),
                content_type="application/json",
            )

            assert response.status_code == 409
            data = json.loads(response.data)
            assert "already exists" in data["error"]

    def test_delete_student_success(self, client, create_sample_student):
        """Test successful student deletion"""
        student_id = create_sample_student.id

        response = client.delete(f"/api/v1/students/{student_id}")

        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["message"] == "Student deleted successfully"

        # Verify student is actually deleted
        get_response = client.get(f"/api/v1/students/{student_id}")
        assert get_response.status_code == 404

    def test_delete_student_not_found(self, client):
        """Test deleting non-existent student"""
        response = client.delete("/api/v1/students/999")

        assert response.status_code == 404
        data = json.loads(response.data)
        assert data["error"] == "Student not found"

    def test_invalid_endpoint(self, client):
        """Test accessing invalid endpoint"""
        response = client.get("/api/v1/invalid")

        assert response.status_code == 404
        data = json.loads(response.data)
        assert data["error"] == "Endpoint not found"

    def test_invalid_http_method(self, client):
        """Test using invalid HTTP method"""
        response = client.patch("/api/v1/students/1")
        assert response.status_code == 405  # Method Not Allowed
