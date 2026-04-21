1. In `/api/main.py` change the host from `localhost` to `redis` on `line 8` and in `/worker/worker.py` on `line 6`. Both needs to point to `Redis` instance container not the localhost only available when the application is run on local machine. To run the application via compose, we have to use the service name define on the `compose.yaml` file. This is how compose allow containers to communicate with each other.

```
File - main.py
Line - 8
Problem - host
Change - localhost → redis
```

```
File - worker.py
Line - 6
Problem - host
Change - localhost → redis
```

```
r = redis.Redis(host="redis", port=6379)
```

2. In `/frontend/app.js` change the host from `localhost` to `api` on `line 6`. The service name defined on `compose.yaml` is supposed to be used to enable the `frontend` container communicate with the `api` container.

```
File - app.js
Line - 6
Problem - host
Change - localhost → api
```

```
const API_URL = "http://api:8000"
```

3. No `health` endpoint on `api` and `frontend` application to test the health status of their containers. A GET `/health` endpoint is added to both apps for us to use `curl` command to check that these containers are healthy.

File - main.py
Line - 27
Problem - No health endpoint

```python
@app.get("/health")
def health_check():
    return {"status": "ok"}
```

File - app.js
Line - 29
Problem - No health endpoint

```javascript
app.get("/health", async (req, res) => {
  res.json({ status: "ok" })
})
```

4. Moved the `redis` host and port to `.env` for `api` and `worker` application. To improve consistency across application for both applications depending on `Redis` instance. Also store the `API_URL` and `PORT` of the frontend app in a `.env` to improve consistency across app.

```python

r = redis.Redis(host=os.getenv("REDIS_HOST"), port=os.getenv("REDIS_PORT"))
```

```javascript
const API_URL = process.env.API_URL
const PORT = process.env.PORT
```
