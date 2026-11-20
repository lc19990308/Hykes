package com.hykes.haidou;

import com.hykes.haidou.service.DatasetPublisher;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;

@SpringBootApplication
public class HaidouApplication {
    public static void main(String[] args) throws Exception {
        List<String> options = new ArrayList<>();
        Path source = null;
        String rollback = null;
        boolean fixture = false;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--publish" -> source = Path.of(argument(args, ++i, "--publish"));
                case "--rollback" -> rollback = argument(args, ++i, "--rollback");
                case "--allow-broken-references" -> fixture = true;
                default -> options.add(args[i]);
            }
        }
        if (source == null && rollback == null && !fixture) {
            SpringApplication.run(HaidouApplication.class, args);
            return;
        }
        if ((source == null) == (rollback == null) || (fixture && source == null)) {
            throw new IllegalArgumentException("Use --publish <file> or --rollback <datasetVersion>");
        }
        try (var context = new SpringApplicationBuilder(HaidouApplication.class)
                .web(WebApplicationType.NONE).run(options.toArray(String[]::new))) {
            var publisher = context.getBean(DatasetPublisher.class);
            System.out.println(source != null ? publisher.publish(source, fixture) : publisher.rollback(rollback));
        }
    }

    private static String argument(String[] args, int i, String flag) {
        if (i >= args.length || args[i].startsWith("--")) {
            throw new IllegalArgumentException("Missing argument for " + flag);
        }
        return args[i];
    }
}
