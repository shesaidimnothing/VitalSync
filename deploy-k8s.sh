#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$PROJECT_DIR/k8s"
BACKEND_IMAGE="vitalsync/backend:latest"
FRONTEND_IMAGE="vitalsync/frontend:latest"

# ── Pré-requis ───────────────────────────────────────────────────────
command -v docker   >/dev/null || error "Docker n'est pas installé."
command -v kubectl  >/dev/null || error "kubectl n'est pas installé."
command -v minikube >/dev/null || error "Minikube n'est pas installé."

# ── Démarrer Minikube si nécessaire ──────────────────────────────────
if ! minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  info "Démarrage de Minikube..."
  minikube start --driver=docker
else
  info "Minikube est déjà en cours d'exécution."
fi

# ── Configurer le Docker daemon de Minikube ──────────────────────────
info "Configuration du Docker daemon Minikube..."
eval "$(minikube docker-env)"

# ── Construire les images Docker dans Minikube ───────────────────────
info "Construction de l'image backend..."
docker build -t "$BACKEND_IMAGE" "$PROJECT_DIR/backend"

info "Construction de l'image frontend..."
docker build -t "$FRONTEND_IMAGE" "$PROJECT_DIR/frontend"

# ── Mettre à jour les manifestes avec les noms d'images locaux ───────
info "Application des manifestes Kubernetes..."

kubectl apply -f "$K8S_DIR/db-secret.yml"
kubectl apply -f "$K8S_DIR/backend-deployment.yml"
kubectl apply -f "$K8S_DIR/backend-service.yml"
kubectl apply -f "$K8S_DIR/frontend-deployment.yml"
kubectl apply -f "$K8S_DIR/frontend-service.yml"
kubectl apply -f "$K8S_DIR/ingress.yml"

# ── Activer l'Ingress Controller si nécessaire ───────────────────────
if ! minikube addons list 2>/dev/null | grep "ingress " | grep -q "enabled"; then
  info "Activation de l'addon Ingress dans Minikube..."
  minikube addons enable ingress
fi

# ── Attendre que les pods soient prêts ───────────────────────────────
info "Attente du démarrage des pods (timeout 120s)..."
kubectl wait --for=condition=ready pod -l app=vitalsync --timeout=120s 2>/dev/null || warn "Certains pods ne sont pas encore prêts."

# ── Afficher l'état du cluster ───────────────────────────────────────
echo ""
info "=== État des pods ==="
kubectl get pods -o wide

echo ""
info "=== État des services ==="
kubectl get services

echo ""
info "=== État de l'Ingress ==="
kubectl get ingress

# ── Accès ─────────────────────────────────────────────────────────────
MINIKUBE_IP=$(minikube ip)
echo ""
info "=== Accès à l'application ==="
echo -e "  Minikube IP        : ${GREEN}${MINIKUBE_IP}${NC}"
echo -e "  Frontend (Ingress) : ${GREEN}http://vitalsync.local${NC}"
echo -e "  Backend  (NodePort): ${GREEN}$(minikube service vitalsync-backend --url 2>/dev/null || echo 'non exposé en NodePort')${NC}"
echo ""
warn "N'oublie pas d'ajouter cette ligne à /etc/hosts si ce n'est pas déjà fait :"
echo -e "  ${YELLOW}${MINIKUBE_IP}  vitalsync.local${NC}"
echo ""
info "Déploiement terminé."
