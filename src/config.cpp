#include "config.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <iostream>
#include <sstream>

namespace {

// Extrae el valor de una línea tipo:  "max_workers": 5,
std::string extract_value(const std::string& line) {
    auto pos = line.find(':');
    if (pos == std::string::npos) return "";
    std::string v = line.substr(pos + 1);
    // Quitar comas, comillas y espacios.
    v.erase(std::remove(v.begin(), v.end(), ','), v.end());
    v.erase(std::remove(v.begin(), v.end(), '"'), v.end());
    v.erase(std::remove_if(v.begin(), v.end(),
                           [](unsigned char c){ return std::isspace(c); }),
            v.end());
    return v;
}

bool has_key(const std::string& line, const std::string& key) {
    return line.find("\"" + key + "\"") != std::string::npos;
}

int to_int(const std::string& s, int fallback) {
    try { return std::stoi(s); }
    catch (...) { return fallback; }
}

void write_default(const std::string& path, const Config& c) {
    std::ofstream out(path);
    if (!out.is_open()) return;
    out << "{\n"
        << "  \"max_workers\": "    << c.max_workers    << ",\n"
        << "  \"max_queue_size\": " << c.max_queue_size << ",\n"
        << "  \"max_timeout_sec\": " << c.max_timeout_sec << ",\n"
        << "  \"data_dir\": \""     << c.data_dir       << "\",\n"
        << "  \"log_file\": \""     << c.log_file       << "\",\n"
        << "  \"socket_path\": \""  << c.socket_path    << "\"\n"
        << "}\n";
    std::cerr << "[config] archivo no encontrado, creado con defaults: "
              << path << "\n";
}

} // namespace

Config load_config(const std::string& path) {
    Config c;
    std::ifstream f(path);
    if (!f.is_open()) {
        write_default(path, c);
        return c;
    }

    std::string line;
    while (std::getline(f, line)) {
        if (has_key(line, "max_workers"))
            c.max_workers     = to_int(extract_value(line), c.max_workers);
        else if (has_key(line, "max_queue_size"))
            c.max_queue_size  = to_int(extract_value(line), c.max_queue_size);
        else if (has_key(line, "max_timeout_sec"))
            c.max_timeout_sec = to_int(extract_value(line), c.max_timeout_sec);
        else if (has_key(line, "data_dir"))
            c.data_dir        = extract_value(line);
        else if (has_key(line, "log_file"))
            c.log_file        = extract_value(line);
        else if (has_key(line, "socket_path"))
            c.socket_path     = extract_value(line);
        else if (has_key(line, "bind_ip"))
            c.bind_ip         = extract_value(line);
        else if (has_key(line, "port"))
            c.port            = to_int(extract_value(line), c.port);
        else if (has_key(line, "allowed_ips")) {
            // La lista viene como: ["127.0.0.1", "192.168.1.0/24"]
            c.allowed_ips.clear();
            auto start = line.find('[');
            auto end   = line.find(']');
            if (start != std::string::npos && end != std::string::npos) {
                std::string list = line.substr(start + 1, end - start - 1);
                std::stringstream ss(list);
                std::string item;
                while (std::getline(ss, item, ',')) {
                    item.erase(std::remove(item.begin(), item.end(), '"'), item.end());
                    item.erase(std::remove_if(item.begin(), item.end(), ::isspace), item.end());
                    if (!item.empty()) c.allowed_ips.push_back(item);
                }
            }
        }
    }
    return c;
}
