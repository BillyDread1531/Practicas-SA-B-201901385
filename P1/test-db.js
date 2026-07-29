require('dotenv').config();

const requestsService = require('./src/services/requests.service');

async function main() {
  try {
    // 1. Crear una solicitud válida
    const nueva = await requestsService.create({
      titulo: 'Compra de sillas',
      area_solicitante: 'Administración',
      prioridad: 4,
      costo_estimado: 1200,
      estado: 'registrada',
    });
    console.log('create (válido) →', nueva);

    // 2. Intentar crear una con prioridad inválida (debería fallar)
    try {
      await requestsService.create({
        titulo: 'Solicitud mala',
        area_solicitante: 'TI',
        prioridad: 9, // fuera de rango
        costo_estimado: 100,
        estado: 'registrada',
      });
      console.log('ERROR: esto no debió pasar, se creó algo inválido');
    } catch (err) {
      console.log('Validación funcionando →', err.name, '-', err.message);
    }

    // 3. Buscar por id existente
    const encontrada = await requestsService.getById(nueva.id);
    console.log('getById (existente) →', encontrada);

    // 4. Buscar por id que NO existe (debería lanzar NotFoundError)
    try {
      await requestsService.getById(99999);
      console.log('ERROR: esto no debió pasar, encontró algo que no existe');
    } catch (err) {
      console.log('NotFound funcionando →', err.name, '-', err.message);
    }

    // 5. Actualizar solo el estado
    const actualizada = await requestsService.updateEstado(nueva.id, 'finalizada');
    console.log('updateEstado →', actualizada);

    // 6. Intentar poner un estado inválido (debería fallar)
    try {
      await requestsService.updateEstado(nueva.id, 'cancelada'); // no existe ese estado
      console.log('ERROR: esto no debió pasar');
    } catch (err) {
      console.log('Validación de estado funcionando →', err.name, '-', err.message);
    }

    // 7. Eliminar
    const eliminada = await requestsService.remove(nueva.id);
    console.log('remove →', eliminada);

  } catch (err) {
    console.error('Error inesperado:', err.message);
  } finally {
    process.exit();
  }
}

main();