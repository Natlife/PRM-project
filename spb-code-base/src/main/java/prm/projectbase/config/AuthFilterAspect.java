package prm.projectbase.config;

import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class AuthFilterAspect {

    @Before("@annotation(authFilter)")
    public void checkAuthPermission(JoinPoint joinPoint, AuthFilter authFilter) {
        String requiredRole = authFilter.permission();
        
        if (requiredRole == null || requiredRole.isBlank()) {
            return;
        }

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        String checkRole = requiredRole.trim();
        String alternateRole = checkRole.startsWith("ROLE_") ? checkRole : "ROLE_" + checkRole;

        boolean hasRole = authentication.getAuthorities().stream()
                .anyMatch(authority -> {
                    String authStr = authority.getAuthority();
                    return authStr.equalsIgnoreCase(checkRole) || authStr.equalsIgnoreCase(alternateRole);
                });

        if (hasRole) {
            return; // Authorized!
        }

        boolean isOwner = false;
        Object principal = authentication.getPrincipal();

        if (principal != null) {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            String[] parameterNames = signature.getParameterNames();
            Object[] args = joinPoint.getArgs();

            if (parameterNames != null && args != null) {
                for (int i = 0; i < parameterNames.length; i++) {
                    if ("id".equals(parameterNames[i])) {
                        Object argValue = args[i];
                        if (argValue != null) {
                            String principalStr = String.valueOf(principal);
                            String argStr = String.valueOf(argValue);
                            if (principalStr.equals(argStr)) {
                                isOwner = true;
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (!isOwner) {
            throw new AccessDeniedException("You do not have permission");
        }
    }
}
