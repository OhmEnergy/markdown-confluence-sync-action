FROM --platform=linux/amd64 node:22
RUN corepack enable && corepack prepare pnpm@9.4.0 --activate

# PATH-A TEST: let puppeteer use its OWN version-matched Chrome-for-Testing instead of
# Debian's system chromium (the suspected version-mismatch cause of the launch failure).
# Fixed cache dir so the build-time download and the runtime launch agree regardless of
# $HOME (GitHub Actions overrides HOME inside the container).
ENV PUPPETEER_CACHE_DIR=/opt/puppeteer-cache

# cspell: disable
# Install Chrome + fonts. Kept NOT to point puppeteer at these binaries, but because the
# apt packages pull in the shared runtime libraries (libnss3, libgbm1, libasound2, ...)
# that puppeteer's own downloaded Chrome links against, plus the fonts Mermaid needs.
RUN apt-get update && apt-get install curl gnupg -y \
  && curl --location --silent https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install google-chrome-stable -y --no-install-recommends \
  && apt-get install chromium -y \
  && apt-get install -y \
    fonts-noto-cjk fonts-noto-color-emoji \
    fonts-terminus fonts-dejavu fonts-freefont-ttf \
    fonts-font-awesome fonts-inconsolata \
    fonts-linuxlibertine \
  && fc-cache -f \
  && rm -rf /var/lib/apt/lists/*

# NOTE: We need to install Mermaid globally, as we are not installing the package.json dependencies due to private packages.
# With PUPPETEER_SKIP_CHROMIUM_DOWNLOAD removed, this global install now triggers the
# bundled puppeteer's postinstall to download the exact Chrome version it expects into
# PUPPETEER_CACHE_DIR — the version match the mermaid-cli docs say is required.
RUN npm i -g mermaid@11.5.0 @mermaid-js/mermaid-cli@11.4.0

WORKDIR /usr/src/app

COPY . .

ENTRYPOINT [ "node", "/usr/src/app/bin/markdown-confluence-sync-action.js"]
