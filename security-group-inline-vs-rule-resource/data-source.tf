data "local_file" "example" {
  filename = "${path.module}/demo.txt"
}

output "file_content" {
  value = data.local_file.example.content
}