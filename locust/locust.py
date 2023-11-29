from locust import HttpUser, task, between
class QuickstartUser(HttpUser):

    @task
    def index_page(self):
        self.client.get("/")