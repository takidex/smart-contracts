const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Vega_Marketing_DAOModule", (m) => {
  const tetherAddr = m.getParameter("tetherAddr", "0xdAC17F958D2ee523a2206206994597C13D831ec7");
  const vmdAddr = m.getParameter("vmdAddr", "0xd094FE0397dFa84493b68F2696702d6FB06031D8");

  const vegaMarketingDAO = m.contract("Vega_Marketing_DAO", [tetherAddr, vmdAddr]);

  return { vegaMarketingDAO };
});