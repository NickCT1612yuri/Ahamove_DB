from flask import Flask

from config import Config


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    from routes.orders import bp as orders_bp
    from routes.search import bp as search_bp
    from routes.analytics import bp as analytics_bp

    app.register_blueprint(orders_bp)
    app.register_blueprint(search_bp)
    app.register_blueprint(analytics_bp)

    @app.context_processor
    def inject_debug_sql():
        # Screens can set flask.g.last_sql for the persistent debug footer.
        from flask import g

        return {"last_sql": getattr(g, "last_sql", None)}

    return app
