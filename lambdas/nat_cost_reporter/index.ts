// Demo-only: query NAT gateway metrics and log a simple cost hint.
// In reality, map BytesOutToDestination * data-transfer price for region.
import { CloudWatchClient, GetMetricStatisticsCommand } from "@aws-sdk/client-cloudwatch";

export const handler = async () => {
  const cw = new CloudWatchClient({});
  const now = new Date();
  const start = new Date(now.getTime() - 3600 * 1000 * 24); // last 24h
  const cmd = new GetMetricStatisticsCommand({
    Namespace: "AWS/NATGateway",
    MetricName: "BytesOutToDestination",
    StartTime: start,
    EndTime: now,
    Period: 3600,
    Statistics: ["Sum"],
    Dimensions: [{ Name: "NatGatewayId", Value: "nat-REPLACE_ME" }]
  });
  const res = await cw.send(cmd);
  console.log("NAT BytesOutToDestination (24h hourly sums):", res.Datapoints);
  // TODO: Multiply by regional egress price to estimate cost.
  return { status: "ok", points: res.Datapoints?.length || 0 };
};
