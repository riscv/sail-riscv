//
// A minimal C language file operations test program designed for constrained
// environments, including only the most basic open/write/read/lseek/close APIs.
//
// Compilation and running example:
// gcc c_file_operations_test_final.c -o file_operations_test
// ./file_operations_test
//
// To integrate with CTest, add the following to your CMakeLists.txt:
// add_executable(file_operations_test c_file_operations_test_final.c)
// add_test(NAME file_operations_test COMMAND file_operations_test)
//

#include <stdio.h>    // printf, remove
#include <stdlib.h>   // EXIT_SUCCESS, EXIT_FAILURE
#include <string.h>   // strlen, strcmp
#include <unistd.h>   // close, lseek
#include <fcntl.h>    // open, O_RDWR, O_CREAT
#include <sys/stat.h> // S_IRWXU

// A simple assertion function to check a condition and print the result.
void assert_true(int condition, const char *message, int *all_passed)
{
  if (condition) {
    printf("[PASS] %s\n", message);
  } else {
    printf("[FAIL] %s\n", message);
    *all_passed = 0; // Set the flag to failed
  }
}

int main()
{
  const char *filename = "test_file.txt";
  const char *test_data = "Hello, this is the final CTest file operation test.";

  int all_passed = 1; // Assume all tests pass by default

  // --- 1. Testing open, write, and close APIs ---
  printf("--- Testing open, write, and close APIs ---\n");
  int fd = open(filename, O_RDWR | O_CREAT, S_IRWXU);
  assert_true(fd != -1, "Successfully opened and created the file",
              &all_passed);
  if (fd == -1) {
    return EXIT_FAILURE;
  }

  ssize_t written_bytes = write(fd, test_data, strlen(test_data));
  assert_true(written_bytes == strlen(test_data), "Successfully wrote all data",
              &all_passed);

  int close_result = close(fd);
  assert_true(close_result == 0, "Successfully closed the file descriptor",
              &all_passed);

  // --- 2. Testing read and lseek APIs ---
  printf("\n--- Testing read and lseek APIs ---\n");
  fd = open(filename, O_RDONLY);
  assert_true(fd != -1, "Successfully opened the file for reading",
              &all_passed);
  if (fd == -1) {
    return EXIT_FAILURE;
  }

  // Use lseek to move the file pointer to the beginning
  off_t seek_result = lseek(fd, 0, SEEK_SET);
  assert_true(
      seek_result != (off_t)-1,
      "Successfully used lseek to move the file pointer to the beginning",
      &all_passed);

  char buffer[256];
  memset(buffer, 0, sizeof(buffer));
  ssize_t read_bytes = read(fd, buffer, strlen(test_data));
  assert_true(read_bytes == strlen(test_data), "Successfully read all data",
              &all_passed);
  assert_true(strcmp(buffer, test_data) == 0,
              "Read content matches the written content", &all_passed);

  close(fd);

  // --- 3. Cleanup: Deleting the test file ---
  printf("\n--- Cleaning up the test file ---\n");
  int remove_result = remove(filename);
  assert_true(remove_result == 0, "Successfully removed the test file",
              &all_passed);

  if (all_passed) {
    printf("\nAll tests passed successfully!\n");
    return EXIT_SUCCESS;
  } else {
    printf("\nSome tests failed.\n");
    return EXIT_FAILURE;
  }
}
