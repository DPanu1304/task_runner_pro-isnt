#include "client.h"

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <unistd.h>

#include "ipc.h"
#include "config.h"

namespace {

int one_shot(const std::string& request) {
    // Obtener host y puerto (variables de entorno o config)
    const char* env_host = std::getenv("JOBRUNNER_HOST");
    const char* env_port = std::getenv("JOBRUNNER_PORT");
    
    std::string host = env_host ? env_host : "127.0.0.1";
    int port = env_port ? std::atoi(env_port) : 8080;

    // Si no hay env, intentar leer config.json
    if (!env_host || !env_port) {
        Config cfg = load_config("config.json");
        if (!env_host) host = cfg.bind_ip;
        if (!env_port) port = cfg.port;
    }

    const int fd = ipc::connect_tcp(host, port);
    if (fd < 0) {
        std::cerr << "error: no se pudo conectar al daemon en "
                  << host << ":" << port << "\n";
        return 3;
    }
    ipc::send_all(fd, request);
    // Usamos recv_line porque el daemon responde una sola línea (o bloque)
    const std::string resp = ipc::recv_all(fd);
    ::close(fd);
    std::cout << resp;
    return resp.rfind("OK", 0) == 0 ? 0 : 1;
}

} // namespace

int client_submit(int argc, char** argv) {
    if (argc < 3) { std::cerr << "uso: server submit <cmd> [args...]\n"; return 2; }
    std::string req = "SUBMIT\t" + std::string(argv[2]);
    for (int i = 3; i < argc; ++i) req += "\t" + std::string(argv[i]);
    req += "\n";
    return one_shot(req);
}

int client_status(int argc, char** argv) {
    if (argc < 3) { std::cerr << "uso: server status <id>\n"; return 2; }
    return one_shot("STATUS\t" + std::string(argv[2]) + "\n");
}

int client_list(int argc, char** argv) {
    std::string req = "LIST";
    if (argc >= 3) req += "\t" + std::string(argv[2]);
    req += "\n";
    return one_shot(req);
}

int client_cancel(int argc, char** argv) {
    if (argc < 3) { std::cerr << "uso: server cancel <id>\n"; return 2; }
    return one_shot("CANCEL\t" + std::string(argv[2]) + "\n");
}

int client_shutdown() { return one_shot("SHUTDOWN\n"); }

int client_health() { return one_shot("HEALTH\n"); }
