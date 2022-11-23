FROM hashicorp/tfc-agent:1.4

# Install post apply hook to delete self
RUN mkdir -p /home/tfc-agent/.tfc-agent
ADD --chown=tfc-agent:tfc-agent terraform-hooks/hooks /home/tfc-agent/.tfc-agent/hooks
