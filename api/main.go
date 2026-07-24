package main

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"
)

func main() {
	workerURL := getenv("WORKER_URL", "http://localhost:8081")

	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "healthy", "service": "api"})
	})
	mux.HandleFunc("/api/info", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]any{
			"name":     "go-gin-demo",
			"language": "Go",
			"services": []string{"frontend", "api", "worker"},
		})
	})
	mux.HandleFunc("/api/status", func(w http.ResponseWriter, r *http.Request) {
		proxy(w, http.MethodGet, workerURL+"/status", nil)
	})
	mux.HandleFunc("/api/status/ping", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		body, _ := io.ReadAll(r.Body)
		proxy(w, http.MethodPost, workerURL+"/status/ping", body)
	})

	http.ListenAndServe(":8080", withCORS(mux))
}

func proxy(w http.ResponseWriter, method, url string, body []byte) {
	var reqBody io.Reader
	if body != nil {
		reqBody = bytes.NewReader(body)
	}
	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
