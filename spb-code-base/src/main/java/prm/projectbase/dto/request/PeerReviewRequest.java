package prm.projectbase.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class PeerReviewRequest {

    @NotNull(message = "reviewedGroupId is required")
    Long reviewedGroupId;

    @NotNull(message = "codeQualityScore is required")
    @Min(value = 1, message = "Score must be between 1 and 5")
    @Max(value = 5, message = "Score must be between 1 and 5")
    Integer codeQualityScore;

    @NotNull(message = "uiUxScore is required")
    @Min(value = 1, message = "Score must be between 1 and 5")
    @Max(value = 5, message = "Score must be between 1 and 5")
    Integer uiUxScore;

    @NotNull(message = "featureScore is required")
    @Min(value = 1, message = "Score must be between 1 and 5")
    @Max(value = 5, message = "Score must be between 1 and 5")
    Integer featureScore;

    @NotNull(message = "presentationScore is required")
    @Min(value = 1, message = "Score must be between 1 and 5")
    @Max(value = 5, message = "Score must be between 1 and 5")
    Integer presentationScore;

    String comment;
}
