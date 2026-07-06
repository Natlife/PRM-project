package prm.projectbase.service;

import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@FieldDefaults(level = AccessLevel.PRIVATE)
public class FileService {

    @Value("${file.upload-dir:./upload}")
    String uploadDir;

    @Value("${file.base-url:http://localhost:5001}")
    String baseUrl;

    static final List<String> BANNED_EXTENSIONS = List.of(
            ".html", ".htm", ".xhtml", ".js", ".mjs", ".ts", ".jsx", ".tsx", ".svg", ".xml",
            ".php", ".phtml", ".jsp", ".jspx", ".asp", ".aspx", ".py", ".rb", ".pl",
            ".exe", ".bat", ".cmd", ".sh", ".bash", ".ps1", ".vbs", ".dll", ".so", ".msi"
    );

    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is empty");
        }

        String extension = extractExtension(file.getOriginalFilename());

        if (isBannedExtension(extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File type is not allowed for security reasons.");
        }

        String storedName = UUID.randomUUID() + extension;
        Path uploadPath = Paths.get(uploadDir).toAbsolutePath();

        if (!uploadPath.toFile().exists()) {
            uploadPath.toFile().mkdirs();
        }

        try {
            file.transferTo(uploadPath.resolve(storedName).toFile());
        }
        catch (IOException e) {
            log.error("Failed to store file {}", storedName, e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not save file");
        }

        return baseUrl + "/assets/" + storedName;
    }

    public void delete(String storedName) {
        if (storedName.contains("..") || storedName.contains("/") || storedName.contains("\\")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file name");
        }

        Path filePath = Paths.get(uploadDir).toAbsolutePath().resolve(storedName);
        File file = filePath.toFile();

        if (!file.exists()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found");
        }

        try {
            Files.delete(filePath);
        }
        catch (IOException e) {
            log.error("Could not delete file {} from disk", storedName, e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not delete file");
        }
    }

    public StorageResult storeFile(MultipartFile file, String folder) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is empty");
        }

        String originalFilename = file.getOriginalFilename();
        String extension = extractExtension(originalFilename);

        if (isBannedExtension(extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File type is not allowed for security reasons.");
        }

        String storedName = UUID.randomUUID() + extension;
        String cleanFolder = folder.replaceAll("\\.\\.", "");
        Path targetFolder = Paths.get(uploadDir, cleanFolder).toAbsolutePath();

        if (!targetFolder.toFile().exists()) {
            targetFolder.toFile().mkdirs();
        }

        try {
            file.transferTo(targetFolder.resolve(storedName).toFile());
        } catch (IOException e) {
            log.error("Failed to store file {}", storedName, e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not save file");
        }

        String storageKey = cleanFolder + "/" + storedName;
        return StorageResult.builder()
                .storageKey(storageKey)
                .originalFileName(originalFilename)
                .contentType(file.getContentType())
                .sizeBytes(file.getSize())
                .build();
    }

    public void deleteFile(String storageKey) {
        if (storageKey == null || storageKey.isBlank() || storageKey.contains("..")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file key");
        }

        Path filePath = Paths.get(uploadDir, storageKey).toAbsolutePath();
        File file = filePath.toFile();

        if (file.exists()) {
            try {
                Files.delete(filePath);
            } catch (IOException e) {
                log.error("Could not delete file {} from disk", storageKey, e);
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not delete file");
            }
        }
    }

    @lombok.Getter
    @lombok.Builder
    @lombok.AllArgsConstructor
    public static class StorageResult {
        String storageKey;
        String originalFileName;
        String contentType;
        Long sizeBytes;
    }

    public String getFileUrl(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return "";
        }
        return baseUrl + "/assets/" + storageKey;
    }

    private String extractExtension(String filename) {
        if (filename == null || filename.isBlank()) return "";
        int dot = filename.lastIndexOf('.');
        return dot > 0 ? filename.substring(dot) : "";
    }

    private boolean isBannedExtension(String extension) {
        if (extension == null || extension.isEmpty()) return false;
        String extLower = extension.toLowerCase();
        return BANNED_EXTENSIONS.contains(extLower);
    }
}
