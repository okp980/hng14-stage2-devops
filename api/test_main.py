import api.main as main
from fastapi.testclient import TestClient


class FakeRedis:
    def __init__(self):
        self.lpush_calls = []
        self.hset_calls = []
        self.hget_map = {}

    def lpush(self, key, value):
        self.lpush_calls.append((key, value))

    def hset(self, key, field, value):
        self.hset_calls.append((key, field, value))

    def hget(self, key, field):
        return self.hget_map.get((key, field))


def test_health_returns_ok():
    client = TestClient(main.app)
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_create_job_pushes_to_queue_and_sets_status(monkeypatch):
    fake = FakeRedis()
    monkeypatch.setattr(main, "r", fake)

    client = TestClient(main.app)
    res = client.post("/jobs")

    assert res.status_code == 200
    body = res.json()
    assert "job_id" in body

    job_id = body["job_id"]
    assert fake.lpush_calls == [("job", job_id)]
    assert fake.hset_calls == [(f"job:{job_id}", "status", "queued")]


def test_get_job_returns_not_found_when_missing(monkeypatch):
    fake = FakeRedis()
    monkeypatch.setattr(main, "r", fake)

    client = TestClient(main.app)
    res = client.get("/jobs/does-not-exist")

    assert res.status_code == 200
    assert res.json() == {"error": "not found"}


def test_get_job_returns_decoded_status(monkeypatch):
    fake = FakeRedis()
    fake.hget_map[("job:abc", "status")] = b"queued"
    monkeypatch.setattr(main, "r", fake)

    client = TestClient(main.app)
    res = client.get("/jobs/abc")

    assert res.status_code == 200
    assert res.json() == {"job_id": "abc", "status": "queued"}
