package pl.turu.web.microservice.metrics;

import com.codahale.metrics.Gauge;
import com.codahale.metrics.MetricRegistry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.integration.support.management.*;
import org.springframework.stereotype.Component;

@Component
public class ExportingIntegrationMetricsFactory implements MetricsFactory {
    @Autowired
    private MetricRegistry metricRegistry;

    @Override
    public AbstractMessageChannelMetrics createChannelMetrics(String name) {
        final DefaultMessageChannelMetrics channelMetrics = new DefaultMessageChannelMetrics(name);
        final Gauge<Long> sendCount = channelMetrics::getSendCountLong;
        final Gauge<Long> receiveCount = channelMetrics::getReceiveCountLong;
        metricRegistry.register("app.queues." + name + ".in", sendCount);
        metricRegistry.register("app.queues." + name + ".out", receiveCount);
        return channelMetrics;
    }

    @Override
    public AbstractMessageHandlerMetrics createHandlerMetrics(String name) {
        return new DefaultMessageHandlerMetrics(name);
    }
}
