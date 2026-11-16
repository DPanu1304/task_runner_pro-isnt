#ifndef CONFIG_H
#define CONFIG_H

#include <string>
#include <vector>

struct Config {
    int         max_workers     = 3;              // RF-05: concurrencia máxima
    int         max_queue_size  = 100;            // RF-25: capacidad de cola
    int         max_timeout_sec = 300;            // RF-XX: watchdog de ejecución
    std::string data_dir        = "./data";       // RF-12: persistencia
    std::string log_file        = "jobrunner.log";// RF-14: bitácora
    std::string socket_path     = "/tmp/jobrunner.sock"; // legacy
    std::string bind_ip         = "127.0.0.1";           // Hito 3: IP de escucha
    int         port            = 8080;                  // Hito 3: Puerto TCP
    std::vector<std::string> allowed_ips;                // Hito 3: Whitelist
};

// Carga la configuración desde `config.json`. Si el archivo no existe,
// crea uno con valores por defecto y lo devuelve.
Config load_config(const std::string& path = "config.json");

#endif // CONFIG_H
