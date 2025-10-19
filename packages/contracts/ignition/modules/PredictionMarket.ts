import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Deployment module for PredictionMarket contract
 */
export default buildModule("PredictionMarketModule", (m) => {
  const predictionMarket = m.contract("PredictionMarket");

  return { predictionMarket };
});
