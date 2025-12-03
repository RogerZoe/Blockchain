"use client";
import { ConnectButton, useReadContract } from "thirdweb/react";
import { client } from "./client";
import { getContract } from "thirdweb";
import { sepolia } from "thirdweb/chains";
import { FACTORY_ADDRESS } from "./constant/contracts";
import { CampaignCard } from "../Components/Campaign";
export const dynamic = "force-dynamic";

export default function Home() {
  const contract = getContract({
    client: client,
    chain: sepolia,
    address: FACTORY_ADDRESS,
  });

  const { data: campaigns, isPending } = useReadContract({
    contract,
    method:
      "function getAllCampaigns() view returns ((address campaignAddress, address owner, string name, uint256 creationTime)[])",
    params: [],
  });

  // console.log(campaigns);

  return (
    <main className="p-4 pb-10 min-h-[100vh] flex items-center justify-center container max-w-screen-lg mx-auto">
      <div className="py-10">
        <h1 className="text-4xl">Campaigns:</h1>
        <div className="mt-4 flex flex-wrap flex-grow gap-4">
          {!isPending &&
            campaigns &&
            (campaigns.length > 0 ? (
              campaigns.map((campaign) => (
                <CampaignCard
                  key={campaign.campaignAddress}
                  campaignAddress={campaign.campaignAddress}
                />
              ))
            ) : (
              <p>NO Campaigns found</p>
            ))}
        </div>
      </div>
    </main>
  );
}
