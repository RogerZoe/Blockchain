'use client';
import { client } from "../app/client";
import Link from "next/link";
import { getContract } from "thirdweb";
import { sepolia } from "thirdweb/chains";
import { useReadContract } from "thirdweb/react";

type CampaignCardProps = {
  campaignAddress: string;
};

export const CampaignCard = ({ campaignAddress }: CampaignCardProps) => {
  const contract = getContract({
    client,
    chain: sepolia,
    address: campaignAddress,
  });

  // Read data from contract
  const { data: campgainName, isPending } = useReadContract({
    contract,
    method: "function name() view returns (string)",
    params: [],
  });

  const { data: campaignDescription } =  useReadContract({
    contract,
    method: "function description() view returns (string)",
    params: [],
  });

  const { data: goal } = useReadContract({
    contract,
    method: "function goal() view returns (uint256)",
    params: [],
  });

  const { data: balance } = useReadContract({
    contract,
    method:
      "function getContractBalance() view returns (uint256)",
    params: [],
  });

  // Convert values to number
  const goalAmount = goal ? parseInt(goal.toString()) : 0;
  const fundedAmount = balance ? parseInt(balance.toString()) : 0;

  // Calculate progress %
  let percentage = 0;
  if (goalAmount > 0) {
    percentage = (fundedAmount / goalAmount) * 100;
    if (percentage > 100) percentage = 100;
  }

  return (
    <div className="bg-white border rounded-lg shadow-md p-5 w-full max-w-sm">
      {/* Progress Bar */}
      <div className="mb-4">
        <div className="w-full h-5 bg-gray-200 rounded-full overflow-hidden">
          <div
            className="h-full bg-blue-600 text-white text-xs flex items-center justify-end pr-1 font-bold"
            style={{ width: `${percentage}%` }}
          >
            ${fundedAmount}
          </div>
        </div>
        { percentage < 100 ? (
          <p className="text-xs text-right mt-1 text-gray-600 font-bold">
            {percentage.toFixed(1)}% funded
          </p>
        ):(
          <p className="text-xs text-right mt-1 text-gray-600 font-bold">
            {percentage.toFixed(1)} % funded
          </p>
        )}
      </div>

      {/* Campaign Info */}
      <h3 className="text-xl font-semibold mb-2 text-slate-700">{campgainName || "Loading..."}</h3>
      <p className="text-sm text-gray-700 mb-4">
        {campaignDescription || "Loading description..."}
      </p>

      {/* View Button */}
      <Link href={`/campaign/${campaignAddress}`}>
        <button className="w-full bg-blue-600 hover:bg-blue-700 text-white text-sm py-2 rounded-md transition">
          View Campaign →
        </button>
      </Link>
    </div>
  );
};
// export default 