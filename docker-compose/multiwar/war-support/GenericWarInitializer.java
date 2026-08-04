package org.gridsuite.war;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/**
 * Starts the Spring application whose class name is stored in the WAR.
 *
 * Keeping this initializer shared means local WAR packaging does not require
 * changing the application sources or Maven projects used for Kubernetes.
 */
public class GenericWarInitializer extends SpringBootServletInitializer {

    private Class<?> applicationClass;
    private String configLocation;

    @Override
    public void onStartup(ServletContext servletContext) throws ServletException {
        applicationClass = loadApplicationClass();
        configLocation = "optional:file:/config" + servletContext.getContextPath() + "/";
        super.onStartup(servletContext);
    }

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        if (applicationClass == null) {
            throw new IllegalStateException("Spring application class was not initialized");
        }
        return application.sources(applicationClass)
                .properties("spring.config.additional-location=" + configLocation);
    }

    private static Class<?> loadApplicationClass() throws ServletException {
        try (InputStream resource = GenericWarInitializer.class.getClassLoader()
                .getResourceAsStream("META-INF/war-start-class")) {
            if (resource == null) {
                throw new ServletException("Missing META-INF/war-start-class");
            }
            String className = new String(resource.readAllBytes(), StandardCharsets.UTF_8).trim();
            return Class.forName(className);
        } catch (IOException | ClassNotFoundException e) {
            throw new ServletException("Unable to load the Spring application class", e);
        }
    }
}
