const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VMDModule", (m) => {
  const name = m.getParameter("name", "Vega Marketing DAO");
  const symbol = m.getParameter("symbol", "VMD");

  const vmd = m.contract("VMD", [name, symbol]);

  return { vmd };
});