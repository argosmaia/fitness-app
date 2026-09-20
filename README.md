# Fitness App

Cliente Flutter para a API Laravel 12, com autenticação Sanctum, armazenamento
seguro do token e módulos de saúde.

## Configuração

Copie `env.development.json.example` para `env.development.json` e ajuste a URL.
O arquivo real é ignorado pelo Git.

```bash
flutter run --dart-define-from-file=env.development.json
```

No emulador Android, o host da máquina normalmente é `10.0.2.2`, portanto use
`http://10.0.2.2:8000/api/v1`. Em desktop, `127.0.0.1` funciona quando Laravel
está na mesma máquina. Produção exige HTTPS.

## Ubuntu 22.04

Instale uma vez as dependências nativas:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libsqlite3-dev
```

Compile e instale somente para o usuário atual:

```bash
flutter build linux --release --dart-define-from-file=env.development.json
chmod +x linux/packaging/install-local.sh
./linux/packaging/install-local.sh
```

O bundle fica em `build/linux/x64/release/bundle/`. O instalador adiciona
**Vitta Fitness** ao menu do Ubuntu sem precisar de `sudo`.

### Sincronização Android ↔ Ubuntu

Entre com a mesma conta nos dois dispositivos e configure ambos para o mesmo
Laravel. Cada instalação mantém seu SQLite. Ao autenticar, retomar o app, a
cada cinco minutos ou usar o botão do perfil, o aplicativo envia as mudanças
pendentes para `/sync` e baixa treinos, refeições, sono e hidratação.

`127.0.0.1` significa o próprio dispositivo. Para dispositivos reais, use um
domínio HTTPS ou o IP acessível do servidor, como
`http://192.168.1.20:8000/api/v1` durante desenvolvimento na mesma rede.

## Segurança

- O token Sanctum é salvo por `flutter_secure_storage`, nunca no `.env`.
- Tokens são anexados pelo interceptor e não são registrados em logs.
- Respostas `401` tentam renovar a sessão uma única vez; falha persistente limpa
  o token.
- URLs e caminhos de API estão centralizados, mas não são segredos: qualquer
  informação distribuída no binário/web pode ser inspecionada. Chaves privadas,
  senhas de serviço e outros segredos devem permanecer somente no backend.

## Validação

```bash
flutter analyze
flutter test
```
