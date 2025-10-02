<?php

namespace App\DTO;

class UserDTO
{
    public function __construct(
        public readonly int $id,
        public readonly string $firstName,
        public readonly string $lastName,
        public readonly string $gender,
        public readonly \DateTimeInterface $birthdate
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            id: (int) $data['id'],
            firstName: $data['first_name'],
            lastName: $data['last_name'],
            gender: $data['gender'],
            birthdate: new \DateTime($data['birthdate'])
        );
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'first_name' => $this->firstName,
            'last_name' => $this->lastName,
            'gender' => $this->gender,
            'birthdate' => $this->birthdate->format('Y-m-d'),
        ];
    }
}
