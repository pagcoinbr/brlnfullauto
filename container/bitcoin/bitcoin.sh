#!/bin/bash
set -e

# Configurar logs
echo "=================================================="
echo "Bitcoin Container - Iniciando serviços"
echo "Data: $(date)"
echo "=================================================="

# Função para verificar se um serviço está rodando
wait_for_service() {
    local host=$1
    local port=$2
    local service=$3
    local max_attempts=30
    local attempt=1

    echo "Verificando $service em $host:$port..."
    while [ $attempt -le $max_attempts ]; do
        if nc -z $host $port 2>/dev/null; then
            echo "✓ $service está disponível em $host:$port"
            return 0
        fi
        echo "  Tentativa $attempt/$max_attempts - $service não disponível..."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "✗ $service não ficou disponível após $max_attempts tentativas"
    return 1
}

# Função para verificar se um arquivo de configuração existe
check_config_file() {
    local config_file=$1
    if [ ! -f "$config_file" ]; then
        echo "✗ Arquivo de configuração não encontrado: $config_file"
        return 1
    fi
    echo "✓ Arquivo de configuração encontrado: $config_file"
    return 0
}

# Verificar arquivos de configuração
check_config_file "/data/bitcoin/bitcoin.conf" || {
    echo "Copiando configuração de exemplo..."
    cp /data/bitcoin/bitcoin.conf.example /data/bitcoin/bitcoin.conf
}

# Iniciar i2pd como processo em background
echo "Iniciando i2pd..."
if i2pd --conf=/etc/i2pd/i2pd.conf & then
    I2PD_PID=$!
    echo "✓ i2pd iniciado com PID: $I2PD_PID"
    
    # Aguardar i2pd ficar disponível
    if wait_for_service 127.0.0.1 7656 "I2P SAM"; then
        echo "✓ I2P SAM está funcionando"
    else
        echo "⚠ I2P SAM não está disponível, Bitcoin continuará sem I2P"
    fi
else
    echo "✗ Falha ao iniciar i2pd"
    I2PD_PID=""
fi

# Aguardar Tor ficar disponível (conecta-se ao container tor)
if wait_for_service tor 9050 "Tor SOCKS"; then
    echo "✓ Tor SOCKS está funcionando"
    
    # Verificar e ajustar permissões do arquivo de cookie do Tor
    if [ -f "/var/lib/tor/control_auth_cookie" ]; then
        echo "✓ Arquivo de cookie do Tor encontrado"
        # Tentar ajustar permissões se necessário
        if [ ! -r "/var/lib/tor/control_auth_cookie" ]; then
            echo "Tentando ajustar permissões do cookie do Tor..."
            chmod 644 /var/lib/tor/control_auth_cookie 2>/dev/null || true
        fi
    else
        echo "⚠ Arquivo de cookie do Tor não encontrado"
    fi
else
    echo "⚠ Tor não está disponível, Bitcoin continuará sem Tor"
fi

# Função para encerrar processos graciosamente
cleanup() {
    echo "=================================================="
    echo "Recebido sinal de encerramento, parando serviços..."
    
    if [ -n "$I2PD_PID" ]; then
        echo "Parando i2pd (PID: $I2PD_PID)..."
        kill $I2PD_PID 2>/dev/null || true
        wait $I2PD_PID 2>/dev/null || true
        echo "✓ i2pd parado"
    fi
    
    echo "Encerrando container..."
    exit 0
}

# Configurar tratamento de sinais
trap cleanup TERM INT

# Mostrar informações do sistema
echo "=================================================="
echo "Informações do sistema:"
echo "Bitcoin data dir: /data/bitcoin"
echo "I2P config: /etc/i2pd/i2pd.conf"
echo "Usuário atual: $(whoami)"
echo "UID: $(id -u), GID: $(id -g)"
echo "=================================================="

# Iniciar bitcoind
echo "Iniciando bitcoind..."
exec bitcoind -datadir=/data/bitcoin -conf=/data/bitcoin/bitcoin.conf
