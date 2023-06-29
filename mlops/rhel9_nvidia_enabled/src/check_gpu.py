import torch

if __name__ == "__main__":
    print("Hello, World!")

    cuda_available = torch.cuda.is_available()
    num_cuda_devices = torch.cuda.device_count()
    current_device_index = torch.cuda.current_device()
    current_device_name = torch.cuda.get_device_name(current_device_index)

    print(
        f"Is cuda available: {cuda_available}."
        f"\nNumber of cuda devices: {num_cuda_devices}."
        f"\nCurrent device index: {current_device_index} and device name: {current_device_name}."
    )
