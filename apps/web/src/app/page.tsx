import { Select } from "@radix-ui/themes";

export default function Home() {
  return (
    <div>
      <h1 className="text-4xl font-semibold">Preskor - Prediction Markets</h1>
      {/* Add your UI implementation here */}
      <Select.Root defaultValue="apple">
        <Select.Trigger />
        <Select.Content>
          <Select.Group>
            <Select.Label>Fruits</Select.Label>
            <Select.Item value="orange">Orange</Select.Item>
            <Select.Item value="apple">Apple</Select.Item>
            <Select.Item value="grape" disabled>
              Grape
            </Select.Item>
          </Select.Group>
        </Select.Content>
      </Select.Root>
    </div>
  );
}
