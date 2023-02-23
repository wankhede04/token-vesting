import { ethers, run } from 'hardhat';

const deploy = async () => {
  const [owner] = await ethers.getSigners();
  const deployer = await owner.getAddress();
  console.log("Deployer: ", deployer);
  console.log("Balance: ", (await owner.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const EquityVesting = await ethers.getContractFactory("EquityVesting"); 

  const mintAmount = process.env.MINT_AMOUNT || "10000000000000000000000";
  const admin = process.env.ADMIN || deployer;
  const equityToken = await EquityToken.deploy("Equity Token", "ETKN", mintAmount);
  await equityToken.deployed();

  const vesting = await EquityVesting.deploy(equityToken.address, admin);
  await vesting.deployed();
  
  console.log("EquityToken: ", equityToken.address);
  console.log("EquityVesting: ", vesting.address);

  await verifyTask(equityToken.address, "EquityToken");
  await verifyTask(vesting.address, "EquityVesting");
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error: ', error)
    process.exit(1)
  })


const verifyTask = async (contract: string, name: string) => {
  try {
    await run('verify:verify', {
      address: contract,
    })
  } catch (error) {
    console.log(`ERROR - verify - ${name}!`)
  }
}