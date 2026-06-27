package prm.projectbase.controller;

import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.FileUploadResponse;
import prm.projectbase.service.FileService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("api/file")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class FileController {

    FileService fileService;

    @PostMapping("v1")
    public BaseResponse<FileUploadResponse> upload(@RequestParam("file") MultipartFile file) {
        String url = fileService.store(file);
        return BaseResponse.success(new FileUploadResponse(url), "File uploaded successfully");
    }

    @DeleteMapping("v1/{fileName}")
    public BaseResponse<Void> delete(@PathVariable("fileName") String fileName) {
        fileService.delete(fileName);
        return BaseResponse.success(null, "File deleted successfully");
    }
}
