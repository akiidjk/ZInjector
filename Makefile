.PHONY: build clean run help

# Variables
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
RED = \033[0;31m
BOLD = \033[1m
NC = \033[0m

build:
	@echo -e "$(GREEN)$(BOLD)[BUILD]$(NC) Building the project..."
	@zig build
	@echo -e "$(GREEN)$(BOLD)[BUILD]$(NC) Build completed successfully."

build-prod:
	@echo -e "$(GREEN)$(BOLD)[BUILD]$(NC) Building the project in release mode..."
	@zig build -Drelease
	@echo -e "$(GREEN)$(BOLD)[BUILD]$(NC) Release build completed successfully."

clean:
	@echo -e "$(YELLOW)$(BOLD)[CLEAN]$(NC) Removing zig-out directory..."
	@rm -rf zig-out
	@echo -e "$(YELLOW)$(BOLD)[CLEAN]$(NC) zig-out directory removed."

run: build ./zig-out/bin/zinjector
	@echo -e "$(BLUE)$(BOLD)[RUN]$(NC) Running ./zig-out/bin/zinjector..."
	@./zig-out/bin/zinjector

help:
	@echo -e "$(BOLD)Available commands:$(NC)"
	@echo "  build   - Build the project using zig build"
	@echo "  clean   - Remove the zig-out directory"
	@echo "  run     - Run ./zig-out/bin/zinjector"
	@echo "  help    - Show this help message"
