package pl.turu.web.microservice.metrics;

import com.codahale.metrics.MetricFilter;
import com.codahale.metrics.MetricRegistry;
import com.codahale.metrics.graphite.Graphite;
import com.codahale.metrics.graphite.GraphiteReporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.util.concurrent.TimeUnit;

@Component
@Profile({"int", "prod"})
public class MetricsManager {
    private static final Logger LOG = LoggerFactory.getLogger(MetricsManager.class);

    @Autowired
    private Environment env;

    @Value("${graphite.host}")
    private String hostName;

    @Value("${graphite.port}")
    private String portString;

    @Value("${graphite.prefix}")
    private String metricPrefix;

    @Value("${graphite.frequency-in-sec}")
    private String frequencyString;

    @Autowired
    private MetricRegistry metricsRegistry;

    private GraphiteReporter graphiteReporter;

    @PostConstruct
    public void registerGraphiteReporter() {
        try {
            final int port = Integer.valueOf(portString);
            final int frequency = Integer.valueOf(frequencyString);

            LOG.info("Connecting to Graphite server: {}:{}", hostName, port);
            String fullPrefix = composeFullMetricPrefix();
            final Graphite graphite = new Graphite(new InetSocketAddress(hostName, port));
            graphiteReporter = GraphiteReporter.forRegistry(metricsRegistry)
                    .prefixedWith(fullPrefix)
                    .convertRatesTo(TimeUnit.SECONDS)
                    .convertDurationsTo(TimeUnit.SECONDS)
                    .filter(MetricFilter.ALL)
                    .build(graphite);
            graphiteReporter.start(frequency, TimeUnit.SECONDS);

            LOG.info("Connected successfully to Graphite server: {}:{}, with frequency: {}. Will report under prefix: {}",
                    hostName, port, frequency, fullPrefix);
            LOG.info("Will report following metrics: {}", metricsRegistry.getNames());
        } catch (Throwable e) {
            LOG.warn("Failed to register with graphite !!!!", e);
        }
    }

    private String composeFullMetricPrefix() throws UnknownHostException {
        final String activeProfile = env.getActiveProfiles()[0];
        return activeProfile + "." + metricPrefix;
    }

    @PreDestroy
    public void destroyMetricsContext() {
        LOG.debug("Destroying the metrics context");
        if (graphiteReporter != null) {
            graphiteReporter.stop();
        }
    }
}
