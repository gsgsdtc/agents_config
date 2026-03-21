import os
from flask import Flask, send_from_directory
from flask_restx import Api
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()


def create_app(config_name='development'):
    """Application factory pattern."""
    # Check if static folder exists (for production with frontend)
    static_folder = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'static')
    if os.path.exists(static_folder):
        app = Flask(__name__, static_folder=static_folder, static_url_path='')
    else:
        app = Flask(__name__)

    # Load config
    from app.config import config
    app.config.from_object(config[config_name])

    # Initialize extensions
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    db.init_app(app)
    migrate.init_app(app, db)

    # Create API with Swagger
    api = Api(
        app,
        version='1.0',
        title='{{PROJECT_NAME}} Admin API',
        description='后台管理系统 API 文档',
        doc='/swagger',
        authorizations={
            'Bearer': {
                'type': 'apiKey',
                'in': 'header',
                'name': 'Authorization',
                'description': 'Bearer token authentication'
            }
        }
    )

    # Register namespaces
    from app.api.user import user_ns
    from app.api.auth import auth_ns
    from app.api.health import health_ns

    api.add_namespace(health_ns, path='/api/health')
    api.add_namespace(user_ns, path='/api/users')
    api.add_namespace(auth_ns, path='/api/auth')

    # Serve frontend static files (for production single-image deployment)
    if os.path.exists(static_folder):
        @app.route('/')
        def serve_index():
            return send_from_directory(app.static_folder, 'index.html')

        @app.route('/<path:path>')
        def serve_static(path):
            # If file exists, serve it; otherwise serve index.html for SPA routing
            if os.path.exists(os.path.join(app.static_folder, path)):
                return send_from_directory(app.static_folder, path)
            return send_from_directory(app.static_folder, 'index.html')

    # Create tables
    with app.app_context():
        db.create_all()

    return app
