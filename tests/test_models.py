from models import Student, db


class TestStudentModel:
    """Test suite for Student model"""

    def test_student_creation(self, app):
        """Test creating a student instance"""
        with app.app_context():
            student = Student(
                first_name="John",
                last_name="Doe",
                email="john.doe@example.com",
                age=20,
                grade="A",
            )

            assert student.first_name == "John"
            assert student.last_name == "Doe"
            assert student.email == "john.doe@example.com"
            assert student.age == 20
            assert student.grade == "A"

    def test_student_to_dict(self, app):
        """Test student to_dict method"""
        with app.app_context():
            student = Student(
                first_name="Jane",
                last_name="Smith",
                email="jane.smith@example.com",
                age=22,
                grade="B",
            )
            db.session.add(student)
            db.session.commit()

            student_dict = student.to_dict()

            assert student_dict["first_name"] == "Jane"
            assert student_dict["last_name"] == "Smith"
            assert student_dict["email"] == "jane.smith@example.com"
            assert student_dict["age"] == 22
            assert student_dict["grade"] == "B"
            assert "id" in student_dict
            assert "created_at" in student_dict
            assert "updated_at" in student_dict

    def test_student_repr(self, app):
        """Test student __repr__ method"""
        with app.app_context():
            student = Student(
                first_name="Test", last_name="User", email="test@example.com", age=25
            )
            db.session.add(student)
            db.session.commit()

            expected_repr = f"<Student {student.id}: Test User>"
            assert repr(student) == expected_repr

    def test_student_without_grade(self, app):
        """Test creating student without grade (optional field)"""
        with app.app_context():
            student = Student(
                first_name="No", last_name="Grade", email="nograde@example.com", age=19
            )
            db.session.add(student)
            db.session.commit()

            assert student.grade is None
            student_dict = student.to_dict()
            assert student_dict["grade"] is None
