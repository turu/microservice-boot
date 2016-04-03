package pl.turu.web.microservice;

import com.codahale.metrics.MetricRegistry;
import com.codahale.metrics.jvm.GarbageCollectorMetricSet;
import com.codahale.metrics.jvm.MemoryUsageGaugeSet;
import com.codahale.metrics.jvm.ThreadStatesGaugeSet;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ImportResource;
import org.springframework.context.support.ConversionServiceFactoryBean;
import org.springframework.core.convert.ConversionService;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@ImportResource("applicationContext.xml")
public class Application {
    @Bean
    public ConversionService conversionService() {
        final ConversionServiceFactoryBean factory = new ConversionServiceFactoryBean();
        factory.afterPropertiesSet();
        return factory.getObject();
    }

    @Bean
    public MetricRegistry metricRegistry() {
        final MetricRegistry metricRegistry = new MetricRegistry();
        metricRegistry.register("jvm.memory", new MemoryUsageGaugeSet());
        metricRegistry.register("jvm.threads", new ThreadStatesGaugeSet());
        metricRegistry.register("jvm.gc", new GarbageCollectorMetricSet());
        return metricRegistry;
    }

    public static void main(String[] args) throws Exception {
        ConfigurableApplicationContext context
                = new SpringApplicationBuilder(Application.class).run(args);
    }
}
