/// Tipo de cuenta. Equivale a `accounts.type` en el esquema original
/// ('EFECTIVO', 'DEBITO', 'CREDITO').
enum AccountType { efectivo, debito, credito }

/// Tipo de categoría. Equivale a `categories.type`
/// ('INGRESO', 'GASTO').
enum CategoryType { ingreso, gasto }

/// Tipo de obligación. Equivale a `obligations.type`
/// ('GASTO_FIJO', 'PROGRESIVO', 'INGRESO_FIJO').
enum ObligationType { gastoFijo, progresivo, ingresoFijo }

/// Frecuencia de una obligación. Equivale a `obligations.frequency`
/// ('MENSUAL', 'QUINCENAL', 'SEMANAL', 'ANUAL').
enum ObligationFrequency { mensual, quincenal, semanal, anual }

/// Estado de una obligación. Equivale a `obligations.status`
/// ('ACTIVO', 'FINALIZADO', 'PAUSADO').
enum ObligationStatus { activo, finalizado, pausado }

/// Tipo de transacción. Equivale a `transactions.type`
/// ('INGRESO', 'GASTO').
enum TransactionType { ingreso, gasto }

/// Estado de una transacción. 'pendiente' = generada por el motor de
/// obligaciones pero aún no confirmada (no afecta el saldo). 'pagado' =
/// dinero que ya se movió de verdad (afecta el saldo). 'cancelado' = una
/// ocurrencia pendiente que el usuario descartó sin pagarla (se conserva
/// para auditoría, tampoco afecta el saldo).
enum TransactionStatus { pendiente, pagado, cancelado }
