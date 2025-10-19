"use client";

import {
  CaretRightIcon,
  ChartLineIcon,
  LockIcon,
  SoccerBallIcon,
} from "@phosphor-icons/react";
import {
  Box,
  Button,
  Container,
  Flex,
  Heading,
  Section,
  Text,
} from "@radix-ui/themes";

export default function Home() {
  return (
    <Box>
      {/* Header */}
      <Box
        style={{
          borderBottom: "1px solid var(--gray-a5)",
          backgroundColor: "var(--color-background)",
        }}
      >
        <Container size="4">
          <Flex justify="between" align="center" py="4">
            <Flex align="center" gap="2">
              <SoccerBallIcon size={32} weight="fill" color="var(--teal-9)" />
              <Heading size="6">Preskor</Heading>
            </Flex>
            <Flex align="center" gap="4">
              <Text size="2">
                <a href="#markets" style={{ color: "var(--gray-11)" }}>
                  Markets
                </a>
              </Text>
              <Text size="2">
                <a href="#about" style={{ color: "var(--gray-11)" }}>
                  About
                </a>
              </Text>
              <Button variant="solid">Connect Wallet</Button>
            </Flex>
          </Flex>
        </Container>
      </Box>

      {/* Hero Section */}
      <Section size="3">
        <Container size="3">
          <Flex
            direction="column"
            align="center"
            gap="6"
            style={{ textAlign: "center" }}
          >
            <Heading size="9" weight="bold">
              Crypto Football
              <br />
              <Text color="teal">Prediction Markets</Text>
            </Heading>
            <Text size="5" color="gray" style={{ maxWidth: "600px" }}>
              Trade on football match outcomes with cryptocurrency. Make
              predictions, earn rewards, and join the future of sports betting.
            </Text>
            <Flex gap="3" wrap="wrap" justify="center">
              <Button size="3" variant="solid">
                Start Trading
                <CaretRightIcon weight="bold" />
              </Button>
              <Button size="3" variant="outline">
                View Markets
              </Button>
            </Flex>
          </Flex>
        </Container>
      </Section>

      {/* Features */}
      <Section size="2" style={{ backgroundColor: "var(--gray-a2)" }}>
        <Container size="3">
          <Flex direction="column" gap="6">
            <Heading size="7" align="center" mb="2">
              Why Preskor?
            </Heading>
            <Flex gap="4" direction={{ initial: "column", md: "row" }}>
              <Box
                p="5"
                style={{
                  backgroundColor: "var(--color-background)",
                  borderRadius: "var(--radius-3)",
                  flex: 1,
                }}
              >
                <Flex
                  direction="column"
                  gap="3"
                  align="center"
                  style={{ textAlign: "center" }}
                >
                  <Flex
                    align="center"
                    justify="center"
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "var(--radius-2)",
                      backgroundColor: "var(--teal-a3)",
                    }}
                  >
                    <SoccerBallIcon
                      size={24}
                      weight="fill"
                      color="var(--teal-9)"
                    />
                  </Flex>
                  <Heading size="4">Live Markets</Heading>
                  <Text color="gray">
                    Trade on live football matches with real-time odds and
                    instant settlement.
                  </Text>
                </Flex>
              </Box>

              <Box
                p="5"
                style={{
                  backgroundColor: "var(--color-background)",
                  borderRadius: "var(--radius-3)",
                  flex: 1,
                }}
              >
                <Flex
                  direction="column"
                  gap="3"
                  align="center"
                  style={{ textAlign: "center" }}
                >
                  <Flex
                    align="center"
                    justify="center"
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "var(--radius-2)",
                      backgroundColor: "var(--teal-a3)",
                    }}
                  >
                    <ChartLineIcon
                      size={24}
                      weight="fill"
                      color="var(--teal-9)"
                    />
                  </Flex>
                  <Heading size="4">Crypto Rewards</Heading>
                  <Text color="gray">
                    Earn cryptocurrency rewards for accurate predictions and
                    market participation.
                  </Text>
                </Flex>
              </Box>

              <Box
                p="5"
                style={{
                  backgroundColor: "var(--color-background)",
                  borderRadius: "var(--radius-3)",
                  flex: 1,
                }}
              >
                <Flex
                  direction="column"
                  gap="3"
                  align="center"
                  style={{ textAlign: "center" }}
                >
                  <Flex
                    align="center"
                    justify="center"
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "var(--radius-2)",
                      backgroundColor: "var(--teal-a3)",
                    }}
                  >
                    <LockIcon size={24} weight="fill" color="var(--teal-9)" />
                  </Flex>
                  <Heading size="4">Decentralized</Heading>
                  <Text color="gray">
                    Transparent, trustless predictions powered by blockchain
                    technology.
                  </Text>
                </Flex>
              </Box>
            </Flex>
          </Flex>
        </Container>
      </Section>
    </Box>
  );
}
