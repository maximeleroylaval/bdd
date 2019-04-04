docker system prune
docker rmi projet_web
docker-compose build --no-cache
docker-compose up