package prm.projectbase.entity.enums;

public enum ActivityType {
    BEFORE_CLASS,
    PRE_CLASS,
    IN_CLASS;

    public String toApiValue() {
        if (this == BEFORE_CLASS) {
            return PRE_CLASS.name();
        }
        return name();
    }
}
