<?php

namespace App\Exception;

use InvalidArgumentException;

class InvalidUserIdException extends InvalidArgumentException
{
    public function __construct(string $userId)
    {
        parent::__construct("Invalid user ID '{$userId}'. Please provide a valid positive number.");
    }
}
