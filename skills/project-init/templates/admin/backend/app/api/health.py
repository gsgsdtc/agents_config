from flask_restx import Namespace, Resource, fields

health_ns = Namespace('health', description='Health check endpoints')

health_model = health_ns.model('Health', {
    'status': fields.String(description='Service status'),
    'message': fields.String(description='Status message'),
})


@health_ns.route('/')
class HealthCheck(Resource):
    @health_ns.doc('health_check')
    @health_ns.marshal_with(health_model)
    def get(self):
        """Check service health."""
        return {
            'status': 'healthy',
            'message': 'Service is running'
        }


@health_ns.route('/ready')
class ReadinessCheck(Resource):
    @health_ns.doc('readiness_check')
    @health_ns.marshal_with(health_model)
    def get(self):
        """Check service readiness."""
        # Add database connectivity check here if needed
        return {
            'status': 'ready',
            'message': 'Service is ready to accept requests'
        }
