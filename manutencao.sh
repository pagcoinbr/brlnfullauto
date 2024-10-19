## Este script serve apra manutenção do BRLNFullauto

lnd_update () {
  cd /tmp
  read -p "Deseja atualizar o LND para qual versão? (Ex: 0.18.3) " LND_VERSION
{
    wget -q https://github.com/lightningnetwork/lnd/releases/download/v$LND_VERSION-beta/lnd-linux-amd64-v$LND_VERSION-beta.tar.gz
    wget -q https://github.com/lightningnetwork/lnd/releases/download/v$LND_VERSION-beta/manifest-v$LND_VERSION-beta.txt.ots
    wget -q https://github.com/lightningnetwork/lnd/releases/download/v$LND_VERSION-beta/manifest-v$LND_VERSION-beta.txt
    wget -q https://github.com/lightningnetwork/lnd/releases/download/v$LND_VERSION-beta/manifest-roasbeef-v$LND_VERSION-beta.sig.ots
    wget -q https://github.com/lightningnetwork/lnd/releases/download/v$LND_VERSION-beta/manifest-roasbeef-v$LND_VERSION-beta.sig
    sha256sum --check manifest-v$LND_VERSION-beta.txt --ignore-missing
    curl -s https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc | gpg --import
    gpg --verify manifest-roasbeef-v$LND_VERSION-beta.sig manifest-v$LND_VERSION-beta.txt
    tar -xzf lnd-linux-amd64-v$LND_VERSION-beta.tar.gz
    sudo install -m 0755 -o root -g root -t /usr/local/bin lnd-linux-amd64-v$LND_VERSION-beta/lnd lnd-linux-amd64-v$LND_VERSION-beta/lncli
    sudo rm -r lnd-linux-amd64-v$LND_VERSION-beta lnd-linux-amd64-v$LND_VERSION-beta.tar.gz manifest-roasbeef-v$LND_VERSION-beta.sig manifest-roasbeef-v$LND_VERSION-beta.sig.ots manifest-v$LND_VERSION-beta.txt manifest-v$LND_VERSION-beta.txt.ots
    sudo systemctl restart lnd
    cd
} &> /dev/null &
echo "Atualizando LND... Por favor, aguarde."
wait
  echo "LND atualizado!"
}

bitcoin_update () {
  cd /tmp
  read -p "Deseja atualizar o Bitcoind para qual versão? (Ex: 28.0) " LND_VERSION
{
wget https://bitcoincore.org/bin/bitcoin-core-$VERSION/bitcoin-$VERSION-x86_64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS.asc
sha256sum --ignore-missing --check SHA256SUMS
curl -s "https://api.github.com/repositories/355107265/contents/builder-keys" | grep download_url | grep -oE "https://[a-zA-Z0-9./-]+" | while read url; do curl -s "$url" | gpg --import; done
gpg --verify SHA256SUMS.asc
tar -xvf bitcoin-$VERSION-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-$VERSION/bin/bitcoin-cli bitcoin-$VERSION/bin/bitcoind
bitcoind --version
sudo rm -r bitcoin-$VERSION bitcoin-$VERSION-x86_64-linux-gnu.tar.gz SHA256SUMS SHA256SUMS.asc
    sudo systemctl restart bitcoind
    cd
} &> /dev/null &
echo "Atualizando LND... Por favor, aguarde."
wait
  echo "LND atualizado!"
}

thunderhub_update () {
  cd /tmp
  read -p "Deseja atualizar o Thunderhub para qual versão? (Ex: 0.13.0) " THUB_VERSION
  sudo systemctl stop thunderhub
  cd thunderhub
  {
  git pull https://github.com/apotdevin/thunderhub.git v$THUB_VERSION
  npm install
  npm run build
  } &> /dev/null &
  echo "Atualizando Thunderhub... Por favor, aguarde."
  wait
  sudo systemctl start thunderhub
  echo "Thunderhub atualizado!"
  head -n 3 /home/thunderhub/thunderhub/package.json | grep version
{

pacotes_do_sistema () {
  sudo apt update && sudo apt upgrade -y
  sudo systemctl reload tor
  if sudo ss -tulpn | grep -q "
  echo "Os pacotes do sistema foram atualizados! Ex: Tor + i2pd + PostgreSQL"

menu() {
  echo "Escolha uma opção:"
  echo "1) Atualizar o LND"
  echo "2) Atualizar o Bitcoind"
  echo "3) Atualizar o Thunderhub"
  echo "4) Atualizar os pacotes do sistema"
  echo "0) Sair"
  read -p "Opção: " option

  case $option in
    1)
      lnd_update
      ;;
    2)
      bitcoin_update
      ;;
    3)
      thunderhub_update
      ;;
    4)
      pacotes_do_sistema
      ;;
    0)
      echo "Saindo..."
      exit 0
      ;;
    *)
      echo "Opção inválida!"
      ;;
  esac
}

lnd --version
bitcoin-cli --version
head -n 3 /home/thunderhub/thunderhub/package.json | grep version
menu