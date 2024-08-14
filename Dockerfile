# syntax=docker/dockerfile:experimental
FROM python:3.11-bookworm

# Install essential packages
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    libgomp1 \
    libxml2-dev libxslt-dev \
    build-essential libmagic-dev \
    openjdk-17-jre-headless \
    tesseract-ocr \
    lsb-release \
    unzip git && \
    echo "deb https://notesalexp.org/tesseract-ocr5/$(lsb_release -cs)/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/notesalexp.list > /dev/null && \
    apt-get update -oAcquire::AllowInsecureRepositories=true && \
    apt-get install notesalexp-keyring -oAcquire::AllowInsecureRepositories=true -y --allow-unauthenticated && \
    apt-get update && \
    apt-get install -y tesseract-ocr libtesseract-dev libmagic1 && \
    wget -P /usr/share/tesseract-ocr/5/tessdata/ https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata && \
    apt-get autoremove -y

# Set the working directory
ENV APP_HOME /app
WORKDIR ${APP_HOME}

# Copy the application code
COPY . ./

# Install Python dependencies
RUN pip install --upgrade pip setuptools
RUN pip install -r requirements.txt

# Install NLTK data (punkt and stopwords) to a specific directory
RUN python -m nltk.downloader -d /usr/local/share/nltk_data punkt stopwords

# Ensure GitHub SSH key is added
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Ensure tiktoken encoding is available
RUN python -c "import tiktoken; tiktoken.get_encoding('cl100k_base')"

# Make the run script executable and expose the application port
RUN chmod +x run.sh
EXPOSE 5001

# Define the command to run the application
CMD ./run.sh
